// ================================================
// ECOAR intel x86 project number 6.3: binary image
// author: PJS_013
// ================================================
// Generally in the c part of the project I have functions that read and write BMP file
// and one function that checks if the input coordinates are correct

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#pragma pack(push, 1)

typedef struct
{
    unsigned short bfType;	// 0x4D42
    unsigned long  bfSize;	// file size in bytes
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned long  bfOffBits;	// offset of pixel data
    unsigned long  biSize;		// header size (bitmap info size)
    long  biWidth;			// image width
    long  biHeight;			// image height
    short biPlanes;			// bitmap planes (== 3)
    short biBitCount;		// bit count of a pixel (== 24)
    unsigned long  biCompression;	// should be 0 (no compression)
    unsigned long  biSizeImage;		// image size (not file size!)
    long biXPelsPerMeter;			// horizontal resolution
    long biYPelsPerMeter;			// vertical resolution
    unsigned long  biClrUsed;		// not important for RGB images
    unsigned long  biClrImportant;	// not important for RGB images
} RGBbmpHdr;

#pragma pack(pop)

typedef struct
{
    unsigned int width, height;
    unsigned int linebytes;
    unsigned char* pImg;
    RGBbmpHdr *pHeader;
} imgInfo;

imgInfo* allocImgInfo()
{
    imgInfo* retv = malloc(sizeof(imgInfo));
    if (retv != NULL)
    {
        retv->width = 0;
        retv->height = 0;
        retv->linebytes = 0;
        retv->pImg = NULL;
        retv->pHeader = NULL;
    }
    return retv;
}

void* freeImgInfo(imgInfo* toFree)
{
    if (toFree != NULL)
    {
        if (toFree->pImg != NULL)
            free(toFree->pImg);
        if (toFree->pHeader != NULL)
            free(toFree->pHeader);
        free(toFree);
    }
    return NULL;
}

void* freeResources(FILE* pFile, imgInfo* toFree)
{
    if (pFile != NULL)
        fclose(pFile);
    return freeImgInfo(toFree);
}

imgInfo* readBMP(const char* fname)
{
    imgInfo* pInfo = 0;
    FILE* fbmp = 0;

    if ((pInfo = allocImgInfo()) == NULL)
        return NULL;

    if ((fbmp = fopen(fname, "rb")) == NULL)
        return freeResources(fbmp, pInfo);  // cannot open file

    if ((pInfo->pHeader = malloc(sizeof(RGBbmpHdr))) == NULL ||
        fread((void *)pInfo->pHeader, sizeof(RGBbmpHdr), 1, fbmp) != 1)
        return freeResources(fbmp, pInfo);

    // several checks - quite restrictive and only for RGB files
    if (pInfo->pHeader->bfType != 0x4D42 || pInfo->pHeader->biPlanes != 1 ||
        pInfo->pHeader->biBitCount != 24 || pInfo->pHeader->biCompression != 0)
        return (imgInfo*) freeResources(fbmp, pInfo);


    if ((pInfo->pImg = malloc(pInfo->pHeader->biSizeImage)) == NULL ||
        fread((void *)pInfo->pImg, 1, pInfo->pHeader->biSizeImage, fbmp) != pInfo->pHeader->biSizeImage)
        return (imgInfo*) freeResources(fbmp, pInfo);

    fclose(fbmp);
    pInfo->width = pInfo->pHeader->biWidth;
    pInfo->height = pInfo->pHeader->biHeight;
    pInfo->linebytes = pInfo->pHeader->biSizeImage / pInfo->pHeader->biHeight;
    return pInfo;
}

int saveBMP(const imgInfo* pInfo, const char* fname)
{
    FILE * fbmp;
    if ((fbmp = fopen(fname, "wb")) == NULL)
        return -1;  // cannot open file for writing

    if (fwrite(pInfo->pHeader, sizeof(RGBbmpHdr), 1, fbmp) != 1  ||
        fwrite(pInfo->pImg, 1, pInfo->pHeader->biSizeImage, fbmp) != pInfo->pHeader->biSizeImage)
    {
        fclose(fbmp);  // cannot write header or image
        return -2;
    }

    fclose(fbmp);
    return 0;
}




unsigned int test_values(unsigned int x1, unsigned int x2, unsigned int y1, unsigned int y2)
{
    if(x1<0||x1>320)
    {
        printf("Error: Coordinate x1 cannot be smaller than 0 or bigger than 320\n");
        return 1;
    }
    if(x2<0||x2>320)
    {
        printf("Error: Coordinate x2 cannot be smaller than 0 or bigger than 320\n");
        return 1;
    }
    if(y1<0||y1>240)
    {
        printf("Error: Coordinate y1 cannot be smaller than 0 or bigger than 240\n");
        return 1;
    }
    if(y2<0||y2>240)
    {
        printf("Error: Coordinate y2 cannot be smaller than 0 or bigger than 240\n");
        return 1;
    }
    if(x1>x2)
    {
        printf("Error: Coordinate x2 cannot be smaller than x1\n");
        return 2;
    }
    if(y2>y1)
    {
        printf("Error: coordinate y1 cannot be smaller than y2\n");
        return 2;
    }
    return 0;
}

extern void get_and_set_color(imgInfo* pImg, unsigned int y, unsigned int x_lower, unsigned int x_upper, unsigned int thresh);

/****************************************************************************************/

int main(int argc, char* argv[])
{
    imgInfo* pInfo;
    unsigned int y = 0;

    if (sizeof(RGBbmpHdr) != 54)
    {
        printf("Check compilation options so as RGBbmpHdr struct size is 54 bytes.\n");
        return 1;
    }
    if ((pInfo = readBMP("source.bmp")) == NULL)
    {
        printf("Error reading source file (probably).\n");
        return 2;
    }


    unsigned int x1;
    unsigned int x2;
    unsigned int y1;
    unsigned int y2;
    unsigned int thresh;



    printf("Enter coordinate x1 of top left corner\n");
    scanf("%d", &x1);
    printf("Enter coordinate y1 of top left corner\n");
    scanf("%d", &y1);
    printf("Enter coordinate x2 of bottom right corner\n");
    scanf("%d", &x2);
    printf("Enter coordinate y2 of bottom right corner\n");
    scanf("%d", &y2);
    printf("Enter threshold value\n");
    scanf("%d", &thresh);

/*I'd like to leave here a little comment on why I don't check values of threshold.
Generally, the program is working correctly regardless of threshold value.
If I set the threshold value to any negative value I just receive a black image
which obviously makes sense, as in the properly read bmp file this equality
0.21R + 0.72G + 0.07B <= thresh for negative threshold value will never be satisfied.
Similarly, if I set big value of thresh, e.g. 10000, the equation will be always satisfied
so I will receive a white image as an outcome*/
    if(test_values(x1, x2, y1, y2)!=0){
        return 1;
    }

    for (y = y2; y < y1; y++)
    {
            get_and_set_color(pInfo, y, x1, x2, thresh);
    }

    saveBMP(pInfo, "result.bmp");
    freeResources(NULL, pInfo);
    return 0;
}
